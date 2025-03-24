APP=$(shell ruby -e 'require "./lib/version" and puts ICalPal::NAME')
VERSION=$(shell ruby -e 'require "./lib/version" and puts ICalPal::VERSION')

GEM=$(APP)-$(VERSION).gem

export GITHUB_REPO = icalPal

$(GEM): bin/icalpal lib/*.rb $(APP).gemspec
	gem build $(APP).gemspec -q

clean:
	rm -fv *.gem

install: $(GEM)
	gem install $(GEM)

user-install: $(GEM)
	gem install --user-install $(GEM)

uninstall:
	-gem uninstall $(APP) -ax

rubygems: $(GEM)
	gem push $(GEM) --otp $(CODE) # make rubygems OTP=123456

gemfury: $(GEM)
	fury push $(GEM)

publish: rubygems gemfury

release:
	github-release release -t ${APP}-${VERSION} -n "${APP} ${VERSION}"

upload:
	github-release upload -t ${APP}-${VERSION} -n "${APP}-${VERSION}.gem" -R -f "${APP}-${VERSION}.gem"
