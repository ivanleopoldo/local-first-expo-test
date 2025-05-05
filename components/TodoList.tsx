import { Todo } from '@/lib/db/watermelon/models';
import { withObservables } from '@nozbe/watermelondb/react';
import { FlatList } from 'react-native';
import TodoItem from './TodoItem';

function TodoListBase({ todos }: { todos: Todo[] }) {
  return (
    <FlatList
      contentContainerClassName="bg-zinc-300 m-4 rounded-md"
      data={todos}
      renderItem={({ item }) => <TodoItem item={item} />}
    />
  );
}

const enhance = withObservables(['todos'], ({ todos }) => ({
  todos,
}));

const TodoList = enhance(TodoListBase);
export default TodoList;
