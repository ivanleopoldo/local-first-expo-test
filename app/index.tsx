import { sync } from '@/lib/db/sync';
import { database } from '@/lib/db/watermelon';
import { Todo } from '@/lib/db/watermelon/models';
import { Stack } from 'expo-router';
import { Button, SafeAreaView } from 'react-native';
import TodoList from '@/components/TodoList';

export default function Home() {
  const todos = database.get<Todo>('todos').query();

  return (
    <>
      <Stack.Screen
        options={{
          title: 'Home',
          headerLargeTitle: true,
          headerRight: () => <Button title="Sync" onPress={sync} />,
          headerLeft: () => (
            <Button title="reset" onPress={async () => await database.unsafeResetDatabase()} />
          ),
        }}
      />
      <SafeAreaView>
        <Button
          title="add"
          onPress={async () => {
            await database.write(async () => {
              await database.get<Todo>('todos').create((todo) => {
                todo.title = 'New Todo';
              });
            });
          }}
        />
        <TodoList todos={todos} />
      </SafeAreaView>
    </>
  );
}
