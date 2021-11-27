package internal

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"path/filepath"
)

const (
	_helmSumoLogicChartRelPath = "../../deploy/helm/sumologic/"
	_kindImagesJSONPath        = "kind_images.json"

	EnvNameKindImage = "KIND_NODE_IMAGE"

	YamlPathReceiverMock = "yamls/receiver-mock.yaml"
)

var (
	HelmSumoLogicChartAbsPath string
	KindImages                KindImagesSpec
)

type KindImagesSpec struct {
	Supported []string `json:"supported"`
	Default   string   `json:"default"`
}

func InitializeConstants() error {
	var err error
	HelmSumoLogicChartAbsPath, err = filepath.Abs(_helmSumoLogicChartRelPath)
	if err != nil {
		return err
	}

	b, err := ioutil.ReadFile(_kindImagesJSONPath)
	if err != nil {
		return err
	}
	if err = json.Unmarshal(b, &KindImages); err != nil {
		return err
	}

	log.Printf("Successfully read kind images spec")
	log.Printf("Default kind image: %v", KindImages.Default)
	log.Printf("Supported kind images: %v", KindImages.Supported)
	return nil
}
