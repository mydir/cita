// Copyright 2015-2017 Parity Technologies (UK) Ltd.
// This file is part of Parity.

// This software is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This software is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Parity.  If not, see <http://www.gnu.org/licenses/>.

use std::collections::{VecDeque, HashSet};
use std::hash::Hash;

const COLLECTION_QUEUE_SIZE: usize = 8;

pub struct CacheManager<T>
where
    T: Eq + Hash,
{
    pref_cache_size: usize,
    max_cache_size: usize,
    bytes_per_cache_entry: usize,
    cache_usage: VecDeque<HashSet<T>>,
}

impl<T> CacheManager<T>
where
    T: Eq + Hash,
{
    pub fn new(pref_cache_size: usize, max_cache_size: usize, bytes_per_cache_entry: usize) -> Self {
        CacheManager {
            pref_cache_size,
            max_cache_size,
            bytes_per_cache_entry,
            cache_usage: (0..COLLECTION_QUEUE_SIZE).map(|_| Default::default()).collect(),
        }
    }

    pub fn note_used(&mut self, id: T) {
        if !self.cache_usage[0].contains(&id) {
            if let Some(c) = self.cache_usage.iter_mut().skip(1).find(|e| e.contains(&id)) {
                c.remove(&id);
            }
            self.cache_usage[0].insert(id);
        }
    }

    /// Collects unused objects from cache.
    /// First params is the current size of the cache.
    /// Second one is an with objects to remove. It should also return new size of the cache.
    pub fn collect_garbage<F>(&mut self, current_size: usize, mut notify_unused: F)
    where
        F: FnMut(HashSet<T>) -> usize,
    {
        if current_size < self.pref_cache_size {
            self.rotate_cache_if_needed();
            return;
        }

        for _ in 0..COLLECTION_QUEUE_SIZE {
            if let Some(back) = self.cache_usage.pop_back() {
                let current_size = notify_unused(back);
                self.cache_usage.push_front(Default::default());
                if current_size < self.max_cache_size {
                    break;
                }
            }
        }
    }

    fn rotate_cache_if_needed(&mut self) {
        if self.cache_usage.is_empty() {
            return;
        }

        if self.cache_usage[0].len() * self.bytes_per_cache_entry > self.pref_cache_size / COLLECTION_QUEUE_SIZE {
            if let Some(cache) = self.cache_usage.pop_back() {
                self.cache_usage.push_front(cache);
            }
        }
    }
}
