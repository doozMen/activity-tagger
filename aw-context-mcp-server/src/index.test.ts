import { describe, test, expect } from '@jest/globals';
import { parseContextList, parseEnrichedEvents } from './index.js';

describe('parseContextList', () => {
  test('parses context list output correctly', () => {
    const output = `ID: 123-abc | Time: 2024-03-15 10:30:00 | Context: Working on project | Tags: work, development
ID: 456-def | Time: 2024-03-15 11:00:00 | Context: Team meeting | Tags: meeting`;

    const result = parseContextList(output);
    
    expect(result).toHaveLength(2);
    expect(result[0]).toEqual({
      id: '123-abc',
      timestamp: '2024-03-15 10:30:00',
      context: 'Working on project',
      tags: ['work', 'development']
    });
    expect(result[1]).toEqual({
      id: '456-def',
      timestamp: '2024-03-15 11:00:00',
      context: 'Team meeting',
      tags: ['meeting']
    });
  });

  test('handles empty output', () => {
    const result = parseContextList('');
    expect(result).toEqual([]);
  });
});

describe('parseEnrichedEvents', () => {
  test('parses enriched events correctly', () => {
    const output = `10:30:00 | Chrome - Project Documentation | Context: Working on project
11:00:00 | Zoom - Team Meeting`;

    const result = parseEnrichedEvents(output);
    
    expect(result).toHaveLength(2);
    expect(result[0]).toEqual({
      timestamp: '10:30:00',
      duration: 0,
      data: {
        app: 'Chrome',
        title: 'Project Documentation'
      },
      context: 'Working on project'
    });
    expect(result[1]).toEqual({
      timestamp: '11:00:00',
      duration: 0,
      data: {
        app: 'Zoom',
        title: 'Team Meeting'
      },
      context: undefined
    });
  });
});