package strings

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// Even though the two tests below look identical, they actually take the *test name* itself
// as the input - the fact that function returns the same result is the point. They are
// *not* duplicates.
func Test_ValuesFileFromT(t *testing.T) {
	assert.Equal(t, "values_valuesfilefromt.yaml", ValueFileFromT(t))
}

func TestValuesFileFromT(t *testing.T) {
	assert.Equal(t, "values_valuesfilefromt.yaml", ValueFileFromT(t))
}
