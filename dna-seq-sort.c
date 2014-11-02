#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

typedef struct _SeqIndex {
    long offset;
    int len;
    int score;
    struct _SeqIndex *previous;
} SeqIndex;

void extract_parameters(FILE *in, int *w_match, int *w_mismatch,
                        int *w_gap, int *max_length) {
    if (fscanf(in, "%i,%i,%i,%i\n", w_match, w_mismatch, w_gap, max_length) != 4) {
        assert(0);
    }
}

int read_sequence(FILE *in, int max_length, char *buf) {
    // buf must be of max_length+2 bytes
    // +-----------------+----+----+
    // |   max length    | \n | \0 |
    // +-----------------+----+----+
    char *p = fgets(buf, max_length+2, in);
    if (!p) {
        return 0;  //eof
    }

    int len = strlen(buf);
    if (buf[len-1] == '\n') { //remove the \n
        buf[len-1] = 0;
        len -= 1;
    } else {
        assert(0); // all the lines should finish with a '\n'
    }

    assert(len <= max_length);

    return len;
}

int calculate_score(int w_match, int w_mismatch, int w_gap,
                    char *seq_reference, int seq_ref_len, char *seq, int seq_len) {
    int *H = (int*) malloc((seq_ref_len + 1) * (seq_len + 1) * sizeof(int));
    memset(H, 0, (seq_ref_len + 1) * (seq_len + 1) * sizeof(int));

    for (int i = 1; i < seq_ref_len + 1; ++i) {
        for (int j = 1; j < seq_len + 1; ++j) {
            int partial_scores[4];

            int is_a_match = seq_reference[i-1] == seq[j-1];
            partial_scores[0] = 0;
            partial_scores[1] = H[((i-1) * seq_len) + j-1] + (is_a_match? w_match : w_mismatch);
            partial_scores[2] = H[((i  ) * seq_len) + j-1] + w_gap;
            partial_scores[3] = H[((i-1) * seq_len) + j  ] + w_gap;

            int max_score = 0;
            for (int i = 0; i < 4; ++i)
                if (partial_scores[i] > max_score)
                    max_score = partial_scores[i];

            H[((i  ) * seq_len) + j  ] = max_score;
        }
    }
    int total_score = H[((seq_ref_len) * seq_len) + seq_len];
    free(H);

    return total_score;
}

SeqIndex *process(FILE *in, int *seq_counter) {
    int w_match = 0;
    int w_mismatch = 0;
    int w_gap = 0;
    int max_length = 0;
    *seq_counter = 0;

    extract_parameters(in, &w_match, &w_mismatch, &w_gap, &max_length);
    const int max_read = max_length + 2; //see read_sequence

    char seq_reference[max_read];
    int seq_ref_len = read_sequence(in, max_length, seq_reference);

    SeqIndex *last = 0;
    while (!feof(in)) {
        char seq[max_read];
        SeqIndex *s = (SeqIndex*) malloc(sizeof(SeqIndex));

        s->offset = ftell(in);
        s->previous = 0;

        s->len = read_sequence(in, max_length, seq);
        if (!s->len) {
            free(s);
            continue;
        }

        s->previous = last;
        last = s;
        *seq_counter += 1;

        s->score = calculate_score(w_match, w_mismatch, w_gap, seq_reference, seq_ref_len, seq, s->len);
        //printf("%i\n", s->score);
    }

    return last;
}

int cmp(const void *a, const void *b) {
    int result = ((SeqIndex*)b)->score - ((SeqIndex*)a)->score;
    if (result == 0) {
        return ((SeqIndex*)a)->offset - ((SeqIndex*)b)->offset;
    }

    return result;
}

void sort_and_output(FILE *in, FILE *out, SeqIndex *last, int seq_counter) {
    SeqIndex buf[seq_counter];
    int i = 0;
    while (last) {
        buf[i] = *last;
        free(last);
        last = buf[i].previous;
        buf[i].previous = 0; 
        i += 1;
    }
    assert(i == seq_counter);
    qsort(buf, seq_counter, sizeof(SeqIndex), cmp);

    for (int i = 0; i < seq_counter; ++i) {
        fseek(in, buf[i].offset, SEEK_SET);
        char seq[buf[i].len + 1];
        if (fread(seq, 1, buf[i].len, in) != buf[i].len) {
            assert(0);
        }

        seq[buf[i].len] = '\n';
        fwrite(seq, 1, buf[i].len + 1, out);
    }
}

int main(int argc, char* argv[]) {
    if (!(argc == 2 || argc == 3)) {
        printf("Usage: %s <input> [<output>]\n", argv[0]);
        return 1;
    }

    FILE *in = fopen(argv[1], "r");
    if (!in) {
        return 2;
    }

    FILE *out = 0;
    if (argc == 2) {
        out = stdout;
    }
    else {
        out = fopen(argv[2], "w");
    }

    if (!out) {
        fclose(in);
        return 2;
    }

    int seq_counter = 0;
    SeqIndex *last = process(in, &seq_counter);
    sort_and_output(in, out, last, seq_counter);

    fclose(in);
    fclose(out);
    return 0;
}
