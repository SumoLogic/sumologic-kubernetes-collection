package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// JavaAutoInstrumentationSpec defines the desired state of JavaAutoInstrumentation
type JavaAutoInstrumentationSpec struct {
	// INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
	// Important: Run "operator-sdk generate k8s" to regenerate code after modifying this file
	// Add custom validation using kubebuilder tags: https://book-v1.book.kubebuilder.io/beyond_basics/generating_crd.html
	// Currently a placeholder
	JavaOptions string `json:"javaOptions"`
}

// JavaAutoInstrumentationStatus defines the observed state of JavaAutoInstrumentation
type JavaAutoInstrumentationStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "operator-sdk generate k8s" to regenerate code after modifying this file
	// Add custom validation using kubebuilder tags: https://book-v1.book.kubebuilder.io/beyond_basics/generating_crd.html
	// Currently a placeholder
	JavaOptions string `json:"javaOptions"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// JavaAutoInstrumentation is the Schema for the javaautoinstrumentations API
// +kubebuilder:subresource:status
// +kubebuilder:resource:path=javaautoinstrumentations,scope=Namespaced
type JavaAutoInstrumentation struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   JavaAutoInstrumentationSpec   `json:"spec,omitempty"`
	Status JavaAutoInstrumentationStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// JavaAutoInstrumentationList contains a list of JavaAutoInstrumentation
type JavaAutoInstrumentationList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []JavaAutoInstrumentation `json:"items"`
}

func init() {
	SchemeBuilder.Register(&JavaAutoInstrumentation{}, &JavaAutoInstrumentationList{})
}
