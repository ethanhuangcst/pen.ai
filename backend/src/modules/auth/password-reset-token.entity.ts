import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, CreateDateColumn } from 'typeorm';
import { User } from '../users/users.entity';

@Entity('password_reset_tokens')
export class PasswordResetToken {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  token: string;

  @Column()
  user_id: number;

  @ManyToOne(() => User, (user) => user.id)
  user: User;

  @CreateDateColumn()
  created_at: Date;

  @Column()
  expires_at: Date;

  @Column({ default: false })
  used: boolean;
}