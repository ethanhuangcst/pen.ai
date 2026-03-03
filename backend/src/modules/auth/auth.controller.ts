import { Controller, Post, Body, HttpStatus, HttpCode, Patch } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() body: {
    email: string;
    password: string;
  }) {
    return this.authService.login(body.email, body.password);
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async sendPasswordResetEmail(@Body() body: {
    email: string;
  }) {
    const result = await this.authService.sendPasswordResetEmail(body.email);
    if (result) {
      return { message: 'Password reset email sent' };
    } else {
      return { message: 'User not found' };
    }
  }

  @Patch('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() body: {
    token: string;
    newPassword: string;
  }) {
    const result = await this.authService.resetPassword(body.token, body.newPassword);
    return { message: 'Password reset successfully' };
  }
}
