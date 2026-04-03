import {
  Table,
  Column,
  Model,
  DataType,
  CreatedAt,
  UpdatedAt,
  ForeignKey,
  BelongsTo,
  BelongsToMany,
  Index,
} from 'sequelize-typescript';
import { Device } from './device.model';
import { Song } from './song.model';
import { PlaylistSong } from './playlist-song.model';

@Table({ tableName: 'playlists', timestamps: true })
export class Playlist extends Model {
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

  @Column({ type: DataType.STRING(255), allowNull: false })
  declare title: string;

  @Column({ type: DataType.TEXT, allowNull: true })
  declare description: string | null;

  @Column({ type: DataType.BOOLEAN, defaultValue: false })
  declare isPublic: boolean;

  @Index({ unique: true })
  @Column({ type: DataType.STRING(12), allowNull: true, unique: true })
  declare shareCode: string | null;

  @BelongsToMany(() => Song, () => PlaylistSong)
  declare songs: Song[];

  @CreatedAt
  declare createdAt: Date;

  @UpdatedAt
  declare updatedAt: Date;
}
