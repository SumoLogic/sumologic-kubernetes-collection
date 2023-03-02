package receivermock

import (
	"regexp"

	log "k8s.io/klog/v2"
)

// Labels represent a key value mapping of labels names and their values.
// An empty label value indicates that we're interested in a label being present
// but we don't care about it's value.
type Labels map[string]string

func (labels Labels) Match(label, value string) bool {
	v, ok := labels[label]
	if !ok {
		log.Infof("Label: %q not present in labels", label)
		return false
	}

	if value == "" { // special case
		return true
	}

	if value != "" && value != v {
		log.Infof("Requested label %q exists in label set but has a different value %q", label, v)
		return false
	}
	return true
}

func (labels Labels) MatchRegex(label string, re *regexp.Regexp) bool {
	v, ok := labels[label]
	if !ok {
		log.Infof("Label: %q not present in labels", label)
		return false
	}
	if !re.MatchString(v) {
		log.Infof("Label %q (value %v) doesn't match the designated regex %q", label, v, re.String())
		return false
	}
	return true
}

// MatchAll matches returns whether all the requested labels are present
// and (if a corresponding value has been provided) that all values match
// matching is done via regex if the value is a valid regex, otherwise via strict equality
// the special value "" matches everything for historical reasons
func (labels Labels) MatchAll(requested Labels) bool {
	ret := true
	for label, value := range requested {
		valueRegex, err := regexp.Compile(value)
		var matched bool
		if err != nil {
			matched = labels.Match(label, value)
		} else {
			matched = labels.MatchRegex(label, valueRegex)
		}
		ret = ret && matched
	}
	return ret
}
