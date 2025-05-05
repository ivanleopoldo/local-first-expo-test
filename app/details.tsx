import { Stack, useLocalSearchParams } from 'expo-router';
import { View } from 'react-native';

export default function Details() {
  const { name } = useLocalSearchParams();

  return (
    <>
      <Stack.Screen options={{ title: 'Details' }} />
      <View />
    </>
  );
}
