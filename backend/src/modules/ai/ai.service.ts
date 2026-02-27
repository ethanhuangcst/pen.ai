import { Injectable, BadRequestException, InternalServerErrorException } from '@nestjs/common';

@Injectable()
export class AiService {
  private providers = {
    openai: {
      baseUrl: 'https://api.openai.com/v1',
      apiKey: process.env.OPENAI_API_KEY,
      models: {
        'gpt-4o-mini': 'gpt-4o-mini',
      },
    },
    deepseek: {
      baseUrl: 'https://api.deepseek.com/v1',
      apiKey: process.env.DEEPSEEK_API_KEY,
      models: {
        'deepseek-3.2': 'deepseek-chat',
      },
    },
    qwen: {
      baseUrl: 'https://api.tongyi.aliyun.com/v1',
      apiKey: process.env.QWEN_API_KEY,
      models: {
        'qwen-plus': 'qwen-plus',
      },
    },
  };

  async generateText(
    model: string,
    prompt: string,
    options?: {
      temperature?: number;
      maxTokens?: number;
      user?: string;
    },
  ): Promise<string> {
    // Determine provider from model name
    let provider: keyof typeof this.providers;
    let providerModel: string;

    if (model.startsWith('gpt')) {
      provider = 'openai';
      providerModel = this.providers.openai.models[model as keyof typeof this.providers.openai.models];
    } else if (model.startsWith('deepseek')) {
      provider = 'deepseek';
      providerModel = this.providers.deepseek.models[model as keyof typeof this.providers.deepseek.models];
    } else if (model.startsWith('qwen')) {
      provider = 'qwen';
      providerModel = this.providers.qwen.models[model as keyof typeof this.providers.qwen.models];
    } else {
      throw new BadRequestException(`Unsupported model: ${model}`);
    }

    const providerConfig = this.providers[provider];
    if (!providerConfig.apiKey) {
      throw new BadRequestException(`API key for ${provider} is not configured`);
    }

    try {
      return await this.callProvider(provider, providerModel, prompt, options);
    } catch (error) {
      console.error(`Error calling ${provider} API:`, error);
      throw new InternalServerErrorException(`Failed to generate text with ${model}`);
    }
  }

  private async callProvider(
    provider: keyof typeof this.providers,
    model: string,
    prompt: string,
    options?: {
      temperature?: number;
      maxTokens?: number;
      user?: string;
    },
  ): Promise<string> {
    const config = this.providers[provider];
    const temperature = options?.temperature || 0.7;
    const maxTokens = options?.maxTokens || 1000;

    let url: string;
    let body: any;
    let headers: Record<string, string>;

    switch (provider) {
      case 'openai':
        url = `${config.baseUrl}/chat/completions`;
        body = {
          model,
          messages: [
            { role: 'system', content: 'You are Pen AI, a helpful writing assistant.' },
            { role: 'user', content: prompt },
          ],
          temperature,
          max_tokens: maxTokens,
          user: options?.user,
        };
        headers = {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.apiKey}`,
        };
        break;

      case 'deepseek':
        url = `${config.baseUrl}/chat/completions`;
        body = {
          model,
          messages: [
            { role: 'system', content: 'You are Pen AI, a helpful writing assistant.' },
            { role: 'user', content: prompt },
          ],
          temperature,
          max_tokens: maxTokens,
        };
        headers = {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.apiKey}`,
        };
        break;

      case 'qwen':
        url = `${config.baseUrl}/chat/completions`;
        body = {
          model,
          messages: [
            { role: 'system', content: 'You are Pen AI, a helpful writing assistant.' },
            { role: 'user', content: prompt },
          ],
          temperature,
          max_tokens: maxTokens,
        };
        headers = {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.apiKey}`,
        };
        break;

      default:
        throw new Error(`Unsupported provider: ${provider}`);
    }

    // Make API request
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`API request failed: ${response.status} ${errorText}`);
    }

    const data = await response.json();
    return data.choices[0].message.content;
  }

  async listModels(): Promise<{
    provider: string;
    models: string[];
  }[]> {
    return Object.entries(this.providers).map(([provider, config]) => ({
      provider,
      models: Object.keys(config.models),
    }));
  }
}
