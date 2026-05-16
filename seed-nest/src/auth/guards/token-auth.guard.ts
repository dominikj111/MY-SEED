import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiToken } from '../../entities/api-token.entity';

/**
 * Validates `Authorization: Bearer <token>` against nest_api_tokens table.
 * Attaches `req.user` on success.
 */
@Injectable()
export class TokenAuthGuard implements CanActivate {
  constructor(
    @InjectRepository(ApiToken)
    private readonly tokens: Repository<ApiToken>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const auth: string = req.headers.authorization ?? '';
    if (!auth.startsWith('Bearer ')) {
      throw new UnauthorizedException('Bearer token required');
    }
    const tokenStr = auth.slice(7);
    const apiToken = await this.tokens.findOne({
      where: { token: tokenStr },
      relations: ['user'],
    });
    if (!apiToken) throw new UnauthorizedException('Invalid token');
    req.user = apiToken.user;
    return true;
  }
}
