import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('ai_providers')
export class AIProvider {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 191, nullable: false })
  name: string;

  @Column({ type: 'json', nullable: false })
  base_urls: Record<string, string>;

  @Column({ type: 'varchar', length: 191, nullable: false })
  default_model: string;

  @Column({ type: 'tinyint', default: 1 })
  requires_auth: boolean;

  @Column({ type: 'varchar', length: 191, nullable: false })
  auth_header: string;

  @CreateDateColumn({ type: 'datetime', precision: 3 })
  created_at: Date;

  @UpdateDateColumn({ type: 'datetime', precision: 3, nullable: true })
  updated_at: Date | null;

  // Validation method
  validate(): void {
    if (!this.name) {
      throw new Error('Provider name is required');
    }
    
    if (!this.base_urls || Object.keys(this.base_urls).length === 0) {
      throw new Error('Base URLs are required');
    }
    
    if (!this.default_model) {
      throw new Error('Default model is required');
    }
  }
}
