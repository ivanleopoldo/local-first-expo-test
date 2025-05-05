import { Model } from '@nozbe/watermelondb';
import { field, text, writer } from '@nozbe/watermelondb/decorators';

export class Todo extends Model {
  static table = 'todos';

  //@ts-ignore
  @text('title') title;
  //@ts-ignore
  @field('is_completed') isCompleted;

  //@ts-ignore
  @writer async addTodo(title: string) {
    const newTodo = await this.collections.get('todos').create((todo) => {
      todo.title = title;
    });
    return newTodo;
  }
}
