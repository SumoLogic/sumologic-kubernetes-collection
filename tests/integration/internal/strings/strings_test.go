package strings

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func Test_ValuesFileFromT(t *testing.T) {
	assert.Equal(t, "values_valuesfilefromt.yaml", ValueFileFromT(t))
}

func TestValuesFileFromT(t *testing.T) {
	assert.Equal(t, "values_valuesfilefromt.yaml", ValueFileFromT(t))
}
