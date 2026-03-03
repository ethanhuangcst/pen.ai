import { Injectable, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcrypt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PasswordResetToken } from './password-reset-token.entity';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    @InjectRepository(PasswordResetToken)
    private passwordResetTokenRepository: Repository<PasswordResetToken>,
  ) {}

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      return null;
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return null;
    }

    // Exclude password hash from returned user object
    const { password_hash, ...result } = user;
    return result;
  }

  async login(email: string, password: string): Promise<{
    access_token: string;
    user: any;
  }> {
    const user = await this.validateUser(email, password);
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const payload = { email: user.email, sub: user.id };
    return {
      access_token: this.jwtService.sign(payload),
      user,
    };
  }

  async verifyToken(token: string): Promise<any> {
    try {
      const payload = this.jwtService.verify(token, {
        secret: process.env.JWT_SECRET || 'pen-ai-jwt-secret-key',
      });
      return payload;
    } catch (error) {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }

  async sendPasswordResetEmail(email: string): Promise<boolean> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      return false;
    }

    // Generate reset token
    const token = this.generateResetToken();
    
    // Calculate expiration time (24 hours from now)
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    // Create password reset token record
    const resetToken = this.passwordResetTokenRepository.create({
      token,
      user_id: user.id,
      expires_at: expiresAt,
    });

    await this.passwordResetTokenRepository.save(resetToken);

    // Here you would typically send an email with the reset link
    // For now, we'll just log it
    console.log(`Password reset link for ${email}: https://pen.ai/reset-password?token=${token}`);

    return true;
  }

  async resetPassword(token: string, newPassword: string): Promise<boolean> {
    // Find the token
    const resetToken = await this.passwordResetTokenRepository.findOne({
      where: { token, used: false },
    });

    if (!resetToken) {
      throw new NotFoundException('Invalid or expired reset token');
    }

    // Check if token is expired
    if (new Date() > resetToken.expires_at) {
      throw new UnauthorizedException('Reset token has expired');
    }

    // Get the user
    const user = await this.usersService.findById(resetToken.user_id);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Hash the new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update user's password
    await this.usersService.update(user.id, { password_hash: hashedPassword });

    // Mark token as used
    resetToken.used = true;
    await this.passwordResetTokenRepository.save(resetToken);

    return true;
  }

  private generateResetToken(): string {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let token = '';
    for (let i = 0; i < 32; i++) {
      token += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return token;
  }
}
