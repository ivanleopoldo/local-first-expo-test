import { schema } from './schema';
import { Todo } from './models';
import SQLiteAdapter from '@nozbe/watermelondb/adapters/sqlite';
import { Database } from '@nozbe/watermelondb';

const adapter = new SQLiteAdapter({
  schema,
  dbName: 'todos',
  jsi: true /* Platform.OS === 'ios' */,
  //@ts-ignore
  onSetUpError: (error) => {
    console.error(error);
  },
});

export const database = new Database({
  adapter,
  modelClasses: [Todo],
});
