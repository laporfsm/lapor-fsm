import { EventEmitter } from 'node:events';

export const logEventEmitter = new EventEmitter();

// Event types
export const LOG_EVENTS = {
    NEW_LOG: 'new_log'
};
