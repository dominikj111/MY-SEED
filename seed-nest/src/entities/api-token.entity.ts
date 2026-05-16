import { Column, CreateDateColumn, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from './user.entity';

@Entity('nest_api_tokens')
export class ApiToken {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true, length: 64 })
  token: string;

  @Column({ length: 100 })
  name: string;

  @ManyToOne(() => User, (user) => user.tokens, { onDelete: 'CASCADE' })
  user: User;

  @CreateDateColumn()
  createdAt: Date;
}
