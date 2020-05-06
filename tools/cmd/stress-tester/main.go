// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	opentracing "github.com/opentracing/opentracing-go"
	jaegercfg "github.com/uber/jaeger-client-go/config"
	"github.com/uber/jaeger-client-go"
)

func buildTrace(spanCount int) {
	tracer := opentracing.GlobalTracer()
	parentSpan := tracer.StartSpan("parent")
	parentSpan.SetOperationName("root-span")
	defer parentSpan.Finish()

	currentParent := &parentSpan

	for i := 0; i < spanCount-1; i++ {
		childSpan := tracer.StartSpan(
			"child",
			opentracing.ChildOf((*currentParent).Context()),
		)
		childSpan.SetOperationName(fmt.Sprintf("ancestor-%d", i+1))
		currentParent = &childSpan
		defer childSpan.Finish()
	}
}

func buildSpans(spm int, totalSpans int, cfg *jaegercfg.Configuration) {
	count := 100
	totalCount := 0

	tracesCount := totalSpans/count
	start := time.Now()
	for i := 0; i < tracesCount; i++ {
		buildTrace(count)
		totalCount += count
		duration := time.Now().Sub(start)

		desired_duration_us := int64(float64(totalCount * 60 * 1000 * 1000) / float64(spm))
		//fmt.Printf("Desired duration for %d spans at %d spans/min: %d us\n", totalCount, spm, desired_duration_us)

		sleep_duration_us := desired_duration_us-duration.Microseconds()
		if sleep_duration_us > 0 {
			time.Sleep(time.Duration(sleep_duration_us) * time.Microsecond)
		}
		if i % 100 == 99 {
			// Calculate again to take sleep into account
			duration := time.Now().Sub(start)
			rpm := (60 * 1000 * 1000 * float64(totalCount)) / float64(duration.Microseconds())
			fmt.Printf("[Queue size: %d] ", cfg.Reporter.QueueSize)
			fmt.Printf("Created %d spans in %.3f seconds, or %.1f spans/minute\n", totalCount, float64(duration.Milliseconds())/1000.0, rpm)
		}
	}
}

func main() {
	handleErr := func(message string, err error) {
		if err != nil {
			log.Fatalf("%s: %v\n", message, err)
		}
	}

	cfg, err := jaegercfg.FromEnv()
	handleErr("Could not parse Jaeger env", err)

	cfg.Sampler = &jaegercfg.SamplerConfig{Type: jaeger.SamplerTypeConst, Param: 1.0}
	cfg.ServiceName = "jaeger_stress_tester"
	fmt.Printf("Sampler type: %s param: %.3f\n", cfg.Sampler.Type, cfg.Sampler.Param)

	tracer, closer, err := cfg.NewTracer()
	handleErr("Could not initialize tracer", err)
	fmt.Printf("Collector Endpoint: %s\nLocalAgentHostPort: %s\n", cfg.Reporter.CollectorEndpoint, cfg.Reporter.LocalAgentHostPort)
	defer closer.Close()

	opentracing.SetGlobalTracer(tracer)

	spm, err := strconv.Atoi(os.Getenv("SPANS_PER_MIN"))
	handleErr("SPANS_PER_MIN env variable not provided", err)

	totalSpans, err := strconv.Atoi(os.Getenv("TOTAL_SPANS"))
	if err != nil {
		totalSpans = 10000000
	}

	fmt.Printf("Going to generate %d spans", totalSpans)
	buildSpans(spm, totalSpans, cfg)
}
