import { Model } from '@nozbe/watermelondb';
import { date, field, readonly, text } from '@nozbe/watermelondb/decorators';

export class Todo extends Model {
  static table = 'todos';

  //@ts-ignore
  @text('title') title;
  //@ts-ignore
  @field('is_completed') isCompleted;
  // @ts-ignore
  @readonly @date('created_at') createdAt!: Date;
  // @ts-ignore
  @readonly @date('updated_at') updatedAt!: Date;
  // @ts-ignore
  @date('deleted_at') deletedAt;
}
