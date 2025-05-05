import { schema } from './schema';
import { Todo } from './models';
import SQLiteAdapter from '@nozbe/watermelondb/adapters/sqlite';
import { Database } from '@nozbe/watermelondb';
import migrations from './migrations';
import { setGenerator } from '@nozbe/watermelondb/utils/common/randomId';
import * as Crypto from 'expo-crypto';

const adapter = new SQLiteAdapter({
  schema,
  migrations,
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

setGenerator(() => Crypto.randomUUID());
