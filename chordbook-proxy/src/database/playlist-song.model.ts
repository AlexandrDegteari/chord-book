import {
  Table,
  Column,
  Model,
  DataType,
  ForeignKey,
} from 'sequelize-typescript';
import { Playlist } from './playlist.model';
import { Song } from './song.model';

@Table({ tableName: 'playlist_songs', timestamps: false })
export class PlaylistSong extends Model {
  @Column({
    type: DataType.UUID,
    defaultValue: DataType.UUIDV4,
    primaryKey: true,
  })
  declare id: string;

  @ForeignKey(() => Playlist)
  @Column({ type: DataType.UUID, allowNull: false })
  declare playlistId: string;

  @ForeignKey(() => Song)
  @Column({ type: DataType.UUID, allowNull: false })
  declare songId: string;

  @Column({ type: DataType.INTEGER, defaultValue: 0 })
  declare position: number;

  @Column({ type: DataType.DATE, defaultValue: DataType.NOW })
  declare addedAt: Date;
}
