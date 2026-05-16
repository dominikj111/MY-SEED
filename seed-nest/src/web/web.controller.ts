import {
  Body,
  Controller,
  Get,
  Logger,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { AuthenticatedGuard } from '../auth/guards/authenticated.guard';
import { LocalAuthGuard } from '../auth/guards/local-auth.guard';
import { MailService } from '../mail/mail.service';
import { WebService } from './web.service';
import { User } from '../entities/user.entity';

@Controller()
export class WebController {
  private readonly logger = new Logger(WebController.name);

  constructor(
    private readonly webService: WebService,
    private readonly mail: MailService,
  ) {}

  @Get()
  index(@Req() req: Request, @Res() res: Response) {
    res.render('index', { user: req.user, title: 'Home · the-seed NestJS' });
  }

  @Get('login')
  loginPage(@Req() req: Request, @Res() res: Response) {
    if (req.isAuthenticated()) return res.redirect('/nest/dashboard');
    const next = (req.query.next as string) ?? '';
    res.render('login', { next, title: 'Login · the-seed NestJS' });
  }

  @UseGuards(LocalAuthGuard)
  @Post('login')
  login(@Req() req: Request, @Res() res: Response, @Body() body: any) {
    const user = req.user as User;
    this.logger.log(`User ${user.email} logged in`);
    const next = body.next || '/nest/dashboard';
    res.redirect(next);
  }

  @Post('logout')
  logout(@Req() req: Request, @Res() res: Response) {
    const email = (req.user as User)?.email ?? 'anonymous';
    req.logout(() => {
      this.logger.log(`User ${email} logged out`);
      res.redirect('/nest/');
    });
  }

  @UseGuards(AuthenticatedGuard)
  @Get('dashboard')
  async dashboard(@Req() req: Request, @Res() res: Response) {
    const user = req.user as User;
    const stats = await this.webService.getDashboardStats(user.id);
    res.render('dashboard', {
      user,
      title: 'Dashboard · the-seed NestJS',
      ...stats,
      myTokens: stats.myTokens.map((t) => ({
        name: t.name,
        preview: t.token.slice(0, 16) + '…',
        createdAt: t.createdAt.toISOString().slice(0, 16).replace('T', ' '),
      })),
    });
  }

  @UseGuards(AuthenticatedGuard)
  @Get('contact')
  contactPage(@Req() req: Request, @Res() res: Response) {
    res.render('contact', { user: req.user, title: 'Contact · the-seed NestJS' });
  }

  @UseGuards(AuthenticatedGuard)
  @Post('contact')
  async contact(@Req() req: Request, @Res() res: Response, @Body() body: any) {
    const { name, email, message } = body;
    await this.mail.send({
      to: 'admin@seed.local',
      subject: `Contact from ${name}`,
      text: `From: ${name} <${email}>\n\n${message}`,
    });
    this.logger.log(`Contact email sent from ${name} <${email}>`);
    res.render('contact', {
      user: req.user,
      title: 'Contact · the-seed NestJS',
      sent: true,
    });
  }
}
