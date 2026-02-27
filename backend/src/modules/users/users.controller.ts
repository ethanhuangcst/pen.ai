import { Controller, Post, Get, Put, Delete, Body, Param, HttpStatus, HttpCode } from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from './users.entity';

@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() body: {
    email: string;
    password: string;
    name?: string;
  }): Promise<Partial<User>> {
    const user = await this.usersService.create(
      body.email,
      body.password,
      body.name,
    );
    
    // Exclude password hash from response
    const { password_hash, ...userResponse } = user;
    return userResponse;
  }

  @Get(':id')
  async findById(@Param('id') id: number): Promise<Partial<User>> {
    const user = await this.usersService.findById(id);
    if (!user) {
      throw new Error('User not found');
    }
    
    const { password_hash, ...userResponse } = user;
    return userResponse;
  }

  @Put(':id')
  async update(
    @Param('id') id: number,
    @Body() body: {
      email?: string;
      password?: string;
      name?: string;
    },
  ): Promise<Partial<User>> {
    const updateData: Partial<User> = {};
    
    if (body.email) updateData.email = body.email;
    if (body.password) updateData.password_hash = body.password;
    if (body.name) updateData.name = body.name;
    
    const user = await this.usersService.update(id, updateData);
    
    const { password_hash, ...userResponse } = user;
    return userResponse;
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id') id: number): Promise<void> {
    await this.usersService.delete(id);
  }
}
