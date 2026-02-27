import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserSetting } from './user-setting.entity';
import { Prompt } from './prompt.entity';
import { ApiKey } from './api-key.entity';
import { User } from '../users/users.entity';

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(UserSetting)
    private userSettingsRepository: Repository<UserSetting>,
    @InjectRepository(Prompt)
    private promptsRepository: Repository<Prompt>,
    @InjectRepository(ApiKey)
    private apiKeysRepository: Repository<ApiKey>,
  ) {}

  // User Settings
  async getUserSettings(userId: number): Promise<UserSetting> {
    let settings = await this.userSettingsRepository.findOne({
      where: { user: { id: userId } },
    });

    if (!settings) {
      // Create default settings if none exist
      settings = this.userSettingsRepository.create({
        user: { id: userId } as User,
        default_ai_model: 'gpt-4o-mini',
        writing_style: { tone: 'professional', length: 'medium' },
      });
      settings = await this.userSettingsRepository.save(settings);
    }

    return settings;
  }

  async updateUserSettings(
    userId: number,
    updates: Partial<UserSetting>,
  ): Promise<UserSetting> {
    const settings = await this.getUserSettings(userId);
    Object.assign(settings, updates);
    return this.userSettingsRepository.save(settings);
  }

  // Prompts
  async getPrompts(userId: number): Promise<Prompt[]> {
    return this.promptsRepository.find({
      where: [{ user: { id: userId } }, { is_default: true }],
    });
  }

  async createPrompt(
    userId: number,
    data: {
      name: string;
      content: string;
    },
  ): Promise<Prompt> {
    const prompt = this.promptsRepository.create({
      user: { id: userId } as User,
      name: data.name,
      content: data.content,
      is_default: false,
    });
    return this.promptsRepository.save(prompt);
  }

  async updatePrompt(
    promptId: number,
    userId: number,
    updates: {
      name?: string;
      content?: string;
    },
  ): Promise<Prompt> {
    const prompt = await this.promptsRepository.findOne({
      where: { id: promptId, user: { id: userId } },
    });

    if (!prompt) {
      throw new NotFoundException('Prompt not found');
    }

    Object.assign(prompt, updates);
    return this.promptsRepository.save(prompt);
  }

  async deletePrompt(promptId: number, userId: number): Promise<void> {
    const result = await this.promptsRepository.delete({
      id: promptId,
      user: { id: userId },
    });

    if (result.affected === 0) {
      throw new NotFoundException('Prompt not found');
    }
  }

  // API Keys (Simplified - in production, use proper encryption)
  async getApiKey(userId: number, provider: string): Promise<ApiKey | null> {
    return this.apiKeysRepository.findOne({
      where: { user: { id: userId }, provider },
    });
  }

  async setApiKey(
    userId: number,
    provider: string,
    apiKey: string,
  ): Promise<ApiKey> {
    let existingKey = await this.getApiKey(userId, provider);

    if (existingKey) {
      existingKey.encrypted_key = this.encryptApiKey(apiKey);
      return this.apiKeysRepository.save(existingKey);
    } else {
      const newKey = this.apiKeysRepository.create({
        user: { id: userId } as User,
        provider,
        encrypted_key: this.encryptApiKey(apiKey),
      });
      return this.apiKeysRepository.save(newKey);
    }
  }

  async deleteApiKey(userId: number, provider: string): Promise<void> {
    const result = await this.apiKeysRepository.delete({
      user: { id: userId },
      provider,
    });

    if (result.affected === 0) {
      throw new NotFoundException('API key not found');
    }
  }

  // Simplified encryption (use proper encryption in production)
  private encryptApiKey(apiKey: string): string {
    // In production, use AES-256 encryption with a secure key
    return Buffer.from(apiKey).toString('base64');
  }

  decryptApiKey(encryptedKey: string): string {
    // In production, use AES-256 decryption
    return Buffer.from(encryptedKey, 'base64').toString('utf8');
  }
}
