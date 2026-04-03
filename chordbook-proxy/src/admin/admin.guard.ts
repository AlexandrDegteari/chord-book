import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const token = request.headers['x-admin-token'];
    const adminToken = this.configService.get('ADMIN_TOKEN');

    if (!token || token !== adminToken) {
      throw new UnauthorizedException('Invalid admin token');
    }

    return true;
  }
}
