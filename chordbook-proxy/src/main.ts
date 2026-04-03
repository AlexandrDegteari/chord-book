import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { join } from 'path';
import { NestExpressApplication } from '@nestjs/platform-express';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.enableCors();

  // Serve admin panel at /admin
  app.useStaticAssets(join(__dirname, '..', 'admin'), { prefix: '/admin' });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
