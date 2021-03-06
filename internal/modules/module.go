package modules

import (
	"net/http"

	"k8s.io/apimachinery/pkg/labels"

	"github.com/clastix/capsule-proxy/internal/tenant"
)

type Module interface {
	Path() string
	Methods() []string
	Handle(proxyTenants []*tenant.ProxyTenant, request *http.Request) (selector labels.Selector, err error)
}
