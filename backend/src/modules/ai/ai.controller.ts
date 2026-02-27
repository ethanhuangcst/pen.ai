import { Controller, Post, Get, Body, Query } from '@nestjs/common';
import { AiService } from './ai.service';

@Controller('ai')
export class AiController {
  constructor(private aiService: AiService) {}

  @Post('generate')
  async generateText(@Body() body: {
    model: string;
    prompt: string;
    options?: {
      temperature?: number;
      maxTokens?: number;
      user?: string;
    };
  }): Promise<{
    generatedText: string;
  }> {
    const generatedText = await this.aiService.generateText(
      body.model,
      body.prompt,
      body.options,
    );
    return { generatedText };
  }

  @Get('models')
  async listModels() {
    return this.aiService.listModels();
  }
}
