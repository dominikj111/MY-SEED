import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';

/**
 * Protects web routes — redirects to /nest/login if the session has no user.
 */
@Injectable()
export class AuthenticatedGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    if (req.isAuthenticated()) return true;
    const res = context.switchToHttp().getResponse();
    res.redirect(`/nest/login?next=${encodeURIComponent(req.originalUrl)}`);
    return false;
  }
}
