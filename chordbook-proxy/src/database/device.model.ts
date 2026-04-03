import {
  Table,
  Column,
  Model,
  DataType,
  CreatedAt,
  UpdatedAt,
  HasMany,
  Index,
} from 'sequelize-typescript';
import { Playlist } from './playlist.model';
import { UserSong } from './user-song.model';

@Table({ tableName: 'devices', timestamps: true })
export class Device extends Model {
  @Column({
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
    primaryKey: true,
  })
  declare id: string;

  @Index({ unique: true })
  @Column({ type: DataType.STRING(255), allowNull: false, unique: true })
  declare deviceUuid: string;

  @Column({ type: DataType.STRING(100), allowNull: true })
  declare nickname: string | null;

  @HasMany(() => Playlist)
  declare playlists: Playlist[];

  @HasMany(() => UserSong)
  declare userSongs: UserSong[];

  @CreatedAt
  declare createdAt: Date;

  @UpdatedAt
  declare updatedAt: Date;
}
