import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SettingsService } from './settings.service';
import { SettingsController } from './settings.controller';
import { UserSetting } from './user-setting.entity';
import { Prompt } from './prompt.entity';
import { ApiKey } from './api-key.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UserSetting, Prompt, ApiKey])],
  controllers: [SettingsController],
  providers: [SettingsService],
  exports: [SettingsService],
})
export class SettingsModule {}
