import { Todo } from '@/lib/db/watermelon/models';
import { View, Text, Pressable } from 'react-native';
import { Checkbox } from 'expo-checkbox';
import { useState } from 'react';

export default function TodoItem({ item }: { item: Todo }) {
  const [isCompleted, setIsCompleted] = useState<boolean>(item.isCompleted);
  return (
    <Pressable onPress={() => setIsCompleted((prev) => !prev)}>
      <View className="flex-row items-center justify-between border-b border-gray-200 p-4">
        <Text>{item.title}</Text>
        <Checkbox value={isCompleted} onValueChange={(value) => setIsCompleted(value)} />
      </View>
    </Pressable>
  );
}
