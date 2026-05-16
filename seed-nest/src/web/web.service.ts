import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import { ApiToken } from '../entities/api-token.entity';

@Injectable()
export class WebService {
  constructor(
    @InjectRepository(User) private readonly users: Repository<User>,
    @InjectRepository(ApiToken) private readonly tokens: Repository<ApiToken>,
  ) {}

  async getDashboardStats(userId: number) {
    const [userCount, tokenCount, myTokens] = await Promise.all([
      this.users.count(),
      this.tokens.count(),
      this.tokens.find({ where: { user: { id: userId } }, order: { createdAt: 'DESC' } }),
    ]);
    return { userCount, tokenCount, myTokens };
  }
}
