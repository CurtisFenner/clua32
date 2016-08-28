char add(char a, char b) {
	return a + b;
}

int hailstone(int n) {
	if (n == 1) {
		return 0;
	}
	if (n % 2 == 0) {
		return 1 + hailstone(n / 2);
	}
	return 1 + hailstone(3 * n + 1);
}
