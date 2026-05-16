import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { randomBytes } from 'crypto';
import { AuthService } from '../auth/auth.service';
import { ApiToken } from '../entities/api-token.entity';

@Injectable()
export class ApiService {
  constructor(
    private readonly auth: AuthService,
    @InjectRepository(ApiToken)
    private readonly tokens: Repository<ApiToken>,
  ) {}

  async issueToken(email: string, password: string, name: string): Promise<ApiToken> {
    const user = await this.auth.validateUser(email, password);
    if (!user) throw new UnauthorizedException('Invalid credentials');
    const token = this.tokens.create({
      token: randomBytes(32).toString('hex'),
      name,
      user,
    });
    return this.tokens.save(token);
  }

  async revokeAllTokens(userId: number): Promise<number> {
    const result = await this.tokens.delete({ user: { id: userId } });
    return result.affected ?? 0;
  }
}
