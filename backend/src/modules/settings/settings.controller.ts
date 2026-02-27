import { Controller, Get, Post, Put, Delete, Body, Param, Request } from '@nestjs/common';
import { SettingsService } from './settings.service';

@Controller('settings')
export class SettingsController {
  constructor(private settingsService: SettingsService) {}

  // User Settings
  @Get('user')
  async getUserSettings(@Request() req: any) {
    // In production, use a proper auth guard to get userId
    const userId = req.user?.id || 1; // Temporary for development
    return this.settingsService.getUserSettings(userId);
  }

  @Put('user')
  async updateUserSettings(
    @Request() req: any,
    @Body() body: {
      default_ai_model?: string;
      writing_style?: {
        tone: string;
        length: string;
        [key: string]: any;
      };
    },
  ) {
    const userId = req.user?.id || 1;
    return this.settingsService.updateUserSettings(userId, body);
  }

  // Prompts
  @Get('prompts')
  async getPrompts(@Request() req: any) {
    const userId = req.user?.id || 1;
    return this.settingsService.getPrompts(userId);
  }

  @Post('prompts')
  async createPrompt(
    @Request() req: any,
    @Body() body: {
      name: string;
      content: string;
    },
  ) {
    const userId = req.user?.id || 1;
    return this.settingsService.createPrompt(userId, body);
  }

  @Put('prompts/:id')
  async updatePrompt(
    @Param('id') id: number,
    @Request() req: any,
    @Body() body: {
      name?: string;
      content?: string;
    },
  ) {
    const userId = req.user?.id || 1;
    return this.settingsService.updatePrompt(id, userId, body);
  }

  @Delete('prompts/:id')
  async deletePrompt(@Param('id') id: number, @Request() req: any) {
    const userId = req.user?.id || 1;
    return this.settingsService.deletePrompt(id, userId);
  }

  // API Keys
  @Post('api-keys')
  async setApiKey(
    @Request() req: any,
    @Body() body: {
      provider: string;
      apiKey: string;
    },
  ) {
    const userId = req.user?.id || 1;
    return this.settingsService.setApiKey(userId, body.provider, body.apiKey);
  }

  @Delete('api-keys/:provider')
  async deleteApiKey(@Param('provider') provider: string, @Request() req: any) {
    const userId = req.user?.id || 1;
    return this.settingsService.deleteApiKey(userId, provider);
  }
}
