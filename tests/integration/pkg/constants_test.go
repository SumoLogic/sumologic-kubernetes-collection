package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"path/filepath"
)

const (
	_helmSumoLogicChartRelPath = "../../../deploy/helm/sumologic/"
	_kindImagesJSONPath        = "../kind_images.json"
)

var (
	HelmSumoLogicChartAbsPath string
	KindImages                KindImagesSpec
)

type KindImagesSpec struct {
	Supported []string `json:"supported"`
	Default   string   `json:"default"`
}

func init() {
	var err error
	HelmSumoLogicChartAbsPath, err = filepath.Abs(_helmSumoLogicChartRelPath)
	if err != nil {
		panic(err)
	}

	b, err := ioutil.ReadFile(_kindImagesJSONPath)
	if err != nil {
		panic(err)
	}
	if err = json.Unmarshal(b, &KindImages); err != nil {
		panic(err)
	}

	log.Printf("Successfully read kind images spec, default: %v, supported: %v",
		KindImages.Default, KindImages.Supported,
	)
}
