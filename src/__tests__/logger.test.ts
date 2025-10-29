import { logger } from '../utils/logger';

describe('Logger', () => {
  beforeEach(() => {
    jest.spyOn(console, 'info').mockImplementation();
    jest.spyOn(console, 'warn').mockImplementation();
    jest.spyOn(console, 'error').mockImplementation();
    jest.spyOn(console, 'debug').mockImplementation();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('should log info messages', () => {
    logger.info('Test info message');
    expect(console.info).toHaveBeenCalled();
  });

  test('should log warn messages', () => {
    logger.warn('Test warning message');
    expect(console.warn).toHaveBeenCalled();
  });

  test('should log error messages', () => {
    logger.error('Test error message', new Error('Test error'));
    expect(console.error).toHaveBeenCalled();
  });

  test('should include timestamp in log messages', () => {
    logger.info('Test message');
    const callArgs = (console.info as jest.Mock).mock.calls[0][0];
    expect(callArgs).toMatch(/\[\d{4}-\d{2}-\d{2}T/);
  });

  test('should include log level in messages', () => {
    logger.info('Test message');
    const callArgs = (console.info as jest.Mock).mock.calls[0][0];
    expect(callArgs).toContain('[INFO]');
  });
});
