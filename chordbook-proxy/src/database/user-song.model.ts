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
import { Song } from './song.model';

@Table({ tableName: 'user_songs', timestamps: true })
export class UserSong extends Model {
  @Column({
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
    primaryKey: true,
  })
  declare id: string;

  @ForeignKey(() => Device)
  @Column({ type: DataType.UUID, allowNull: false })
  declare deviceId: string;

  @BelongsTo(() => Device)
  declare device: Device;

  @ForeignKey(() => Song)
  @Column({ type: DataType.UUID, allowNull: true })
  declare originalSongId: string | null;

  @BelongsTo(() => Song)
  declare originalSong: Song;

  @Column({ type: DataType.STRING(500), allowNull: false })
  declare title: string;

  @Column({ type: DataType.STRING(500), allowNull: false })
  declare artist: string;

  @Column({ type: DataType.JSONB, allowNull: false })
  declare sections: any;

  @Column({ type: DataType.BOOLEAN, defaultValue: false })
  declare isPublic: boolean;

  @Index({ unique: true })
  @Column({ type: DataType.STRING(12), allowNull: true, unique: true })
  declare shareCode: string | null;

  @Column({
    type: DataType.ENUM('draft', 'submitted', 'approved', 'rejected'),
    defaultValue: 'draft',
  })
  declare status: 'draft' | 'submitted' | 'approved' | 'rejected';

  @Column({ type: DataType.TEXT, allowNull: true })
  declare adminNotes: string | null;

  @CreatedAt
  declare createdAt: Date;

  @UpdatedAt
  declare updatedAt: Date;
}
