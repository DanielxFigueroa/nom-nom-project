import { generateInviteCode } from './household';

describe('household utilities', () => {
  describe('generateInviteCode', () => {
    it('should generate a 6-character string', () => {
      const code = generateInviteCode();
      expect(typeof code).toBe('string');
      expect(code.length).toBe(6);
    });

    it('should only contain uppercase letters and numbers', () => {
      const code = generateInviteCode();
      const regex = /^[A-Z0-9]{6}$/;
      expect(regex.test(code)).toBe(true);
    });

    it('should generate relatively unique codes', () => {
      const code1 = generateInviteCode();
      const code2 = generateInviteCode();
      expect(code1).not.toBe(code2);
    });
  });
});
