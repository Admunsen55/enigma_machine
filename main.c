#include <stdio.h>

extern void enigma(char *plain, char key[3], char notches[3], char config[10][26], char *enc);

int main() {
    char plain[] = "HELLOWORLD";   // Plain text
    char key[] = "ABC";             // Key
    char notches[] = "XYZ";         // Notches
    char config[10][26];            // Config matrix
    char enc[sizeof(plain)];        // Encrypted text

    // Initialize config matrix (dummy data for testing)
    for (int i = 0; i < 10; i++) {
        for (int j = 0; j < 26; j++) {
            config[i][j] = 'A' + j; // Example: fill with letters 'A' to 'Z'
        }
    }

    // Call the enigma function
    enigma(plain, key, notches, config, enc);

    // Print the encrypted text
    printf("Encrypted text: %s\n", enc);

    return 0;
}
