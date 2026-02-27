import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { AIProvider } from './ai-provider.entity';

@Module({
  imports: [TypeOrmModule.forFeature([AIProvider])],
  controllers: [AiController],
  providers: [AiService],
  exports: [AiService, TypeOrmModule],
})
export class AiModule {}
