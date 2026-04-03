import {
  Table,
  Column,
  Model,
  DataType,
  CreatedAt,
  UpdatedAt,
  ForeignKey,
  BelongsTo,
  Index,
} from 'sequelize-typescript';
import { Device } from './device.model';

@Table({ tableName: 'songs', timestamps: true })
export class Song extends Model {
  @Column({
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
    primaryKey: true,
  })
  declare id: string;

  @Index({ unique: true })
  @Column({ type: DataType.STRING(50), allowNull: true })
  declare externalId: string | null;

  @Column({ type: DataType.STRING(500), allowNull: false })
  declare title: string;

  @Column({ type: DataType.STRING(500), allowNull: false })
  declare artist: string;

  @Column({ type: DataType.TEXT, allowNull: true })
  declare url: string | null;

  @Column({ type: DataType.JSONB, allowNull: false })
  declare sections: any;

  @Column({
    type: DataType.ENUM('scraped', 'user'),
    defaultValue: 'scraped',
  })
  declare source: 'scraped' | 'user';

  @Column({
    type: DataType.ENUM('active', 'pending', 'rejected'),
    defaultValue: 'active',
  })
  declare status: 'active' | 'pending' | 'rejected';

  @ForeignKey(() => Device)
  @Column({ type: DataType.UUID, allowNull: true })
  declare submittedBy: string | null;

  @BelongsTo(() => Device)
  declare submitter: Device;

  @Column({ type: DataType.DATE, allowNull: true })
  declare scrapedAt: Date | null;

  @CreatedAt
  declare createdAt: Date;

  @UpdatedAt
  declare updatedAt: Date;
}
