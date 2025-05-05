import { SyncDatabaseChangeSet, synchronize } from '@nozbe/watermelondb/sync';
import { database } from './watermelon';
import { supabase } from './supabase';

export async function sync() {
  await synchronize({
    database,
    pullChanges: async ({ lastPulledAt }) => {
      console.log(`🍉 Pulling with lastPulledAt = ${lastPulledAt}`);
      // console.log(lastPulledAt);
      const { data, error } = await supabase.rpc('pull', {
        last_pulled_at: lastPulledAt ?? 0,
      });

      if (error) {
        throw new Error('🍉'.concat(error.message));
      }

      const { changes, timestamp } = data as {
        changes: SyncDatabaseChangeSet;
        timestamp: number;
      };

      console.log(`🍉 Changes pulled successfully. Timestamp: ${timestamp}`);

      // console.log(JSON.stringify(changes, null, 2));

      return { changes, timestamp };
    },
    pushChanges: async ({ changes, lastPulledAt }) => {
      console.log(`🍉 Pushing with lastPulledAt = ${lastPulledAt}`);

      // console.log('changes', JSON.stringify(changes, null, 2));

      const { error } = await supabase.rpc('push', { changes });

      if (error) {
        console.log(error);
        throw new Error('🍉'.concat(error.message));
      }

      console.log(`🍉 Changes pushed successfully.`);
    },
    sendCreatedAsUpdated: true,
  });
}
