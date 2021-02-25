class LivePhone {
  constructor(context) {
    // This contains the original context of the LiveView Hook
    this.context = context

    // Used to allows typing to find a country by name
    this.typeahead = {
      timer: -1,
      text: '',
    }

    // Element selector functions
    // These have to be dynamic because not all elements are always present
    // since some are managed by LiveView in the back-end
    this.elements = {
      parent: () => context.el,
      textField: () => context.el.querySelector('input[type="text"]'),
      hiddenField: () => context.el.querySelector('input[type="hidden"]'),
      countrySelector: () => context.el.querySelector('.live_phone-country'),
      countryList: () => context.el.querySelector('.live_phone-country-list'),
      countryListItems: () => context.el.querySelectorAll('.live_phone-country-item'),
      countryListItemNames: () => context.el.querySelectorAll('.live_phone-country-item-name'),
      selectedCountries: () => context.el.querySelectorAll('.live_phone-country-item[aria-selected="true"]'),
    }
  }

  // Is the country list overlay open/visible?
  get isOpened() {
    return this.elements.countryList() != null
  }

  // Is the currently active element (focused) the same as the country selector button?
  get countriesHasFocus() {
    return document.activeElement == this.elements.countrySelector()
  }

  // "Private" method to dispatch events back to the LiveView back-end
  _dispatch(eventName, properties = {}) {
    if (!this.context.el || !this.context.el.id) return
    this.context.pushEventTo('#' + this.context.el.id, eventName, properties)
  }

  // Is the target element contained within our LiveView Component?
  contains(target) {
    return this.elements.parent().contains(target)
  }

  // Close the country list overlay
  closeOverlay() {
    this._dispatch("close")
  }

  // If the click happened within our component we can ignore it,
  // but otherwise we want to close the countries list overlay.
  onOutsideEvent(e) {
    if (this.contains(e.target)) return
    this.closeOverlay()
  }

  // Move the focus to our (visible) textfield
  setFocus() {
    this.elements.textField().focus()
  }

  // This has to happen because the `phx-change` event was not
  // always called correctly when updating the value from the
  // back-end. So this sends a dummy change event to work around it.
  setChange({value: phone}) {
    const changeEvent = new Event('change', {bubbles: true})
    this.elements.hiddenField().dispatchEvent(changeEvent)
  }

  // Move the currently selected country in the country list overlay
  // one up or down
  shiftSelectedCountry(change) {
    const items = Array.from(this.elements.countryListItems())

    // Which country item is currently selected?
    let currentSelection = items.findIndex(item => item.ariaSelected === "true")
    currentSelection = currentSelection === -1 ? 0 : currentSelection

    // Which country item should become selected (clamped between possible values)
    let newSelection = currentSelection + change
    newSelection = Math.min(items.length - 1, Math.max(0, newSelection))

    // Unselect the previous/current selection
    if (items[currentSelection]) {
      items[currentSelection].ariaSelected = "false"
      items[currentSelection].classList.remove('selected')
    }

    // If the new selection exists, select it and scroll it into view.
    if (!items[newSelection]) return
    items[newSelection].ariaSelected = "true"
    items[newSelection].classList.add('selected')

    items[newSelection].scrollIntoView({
      behavior: 'auto',
      block: 'nearest',
      inline: 'nearest'
    })
  }

  onKeyNavigation(e) {
    // key: down arrow
    // Move the selection down (selectedIndex + 1)
    if (e.keyCode == 40) {
      e.preventDefault()
      this.shiftSelectedCountry(+1)

    // key: up arrow
    // Move the selection up (selectedIndex - 1)
    } else if (e.keyCode == 38) {
      e.preventDefault()
      this.shiftSelectedCountry(-1)

    // key: space
    // If the country list overlay is closed and the button
    // has focus, send the click event to the focused element
    } else if (e.keyCode == 32) {
      if (this.isOpened || !this.countriesHasFocus) return
      e.preventDefault()
      document.activeElement.click()

    // key: enter
    // If the country list overlay is closed and the button
    // has focus, send the click event to the focused element
    } else if (e.keyCode == 13) {
      e.preventDefault()
      if (!this.isOpened && this.countriesHasFocus) {
        document.activeElement.click()
        return
      }

      // If the country list is not open, selecting items with
      // enter should not work.
      if (!this.isOpened) {
        return
      }

      const items = Array.from(this.elements.countryListItems())
      const currentItem = items.find(item => item.ariaSelected === "true")

      // Let the back-end know the user selected a different country.
      if (currentItem) {
        this._dispatch("select_country", {
          country: currentItem.getAttribute('phx-value-country')
        })

        // Move focus to the TextField
        this.setFocus()
      } else {
        this.closeOverlay()
      }

    // key: escape
    // Escape simply closes the overlay
    } else if (e.keyCode == 27) {
      e.preventDefault()
      this.closeOverlay()
    }
  }

  findPartialMatch(e) {
    // Ignore events that happen outside of our LiveView Component
    if (!this.contains(e.target)) return

    // We don't want to partial match on the input field value
    if (e.target == "INPUT") return

    // Ignore anything that is not a-zA-Z
    if (!e.key.match(/^[a-z]$/i)) return

    // Let's get a list of all known country list item names
    const items = Array.from(this.elements.countryListItemNames())

    // Every new keypress adds to the already known keypress and
    // if the typeahead text somehow is empty we can do an early return
    this.typeahead.text = (this.typeahead.text + e.key)
    if (!this.typeahead.text) return

    // Generate a regular expression based on the typed letters and
    // find the index for the first matching country list item element
    const regex = new RegExp("^" + this.typeahead.text, "i")
    const firstResult = items.findIndex(item => !!item.innerText.match(regex))

    // This is also where we will keep a reset timer for the typeahead
    // so if you wait with typing for 1.5s it will reset and start over again
    clearTimeout(this.typeahead.timer)
    this.typeahead.timer = setTimeout(() => {
      this.typeahead.text = ''
    }, 1500)

    // If there is no match, early return
    if (firstResult === -1) return

    // Unselect all currently selected countries.
    this.elements.selectedCountries().forEach(f => {
      f.ariaSelected = 'false'
      f.classList.remove('selected')
    })

    // Select the matching country item element and scroll
    // it into view (if needed)
    const countryItemEl = items[firstResult].parentNode
    countryItemEl.ariaSelected = 'true'
    countryItemEl.classList.add('selected')
    countryItemEl.scrollIntoView({
      behavior: 'auto',
      block: 'start',
      inline: 'start'
    })
  }

  bindEvents() {
    // The "focus" event should set focus to the text field
    this.setFocus = this.setFocus.bind(this)
    this.context.handleEvent("focus", this.setFocus)

    // The "change" event should trigger dispatch on the hidden input
    this.setChange = this.setChange.bind(this)
    this.context.handleEvent("change", this.setChange)

    // This is used to close the overlay on events that happen outside
    // of our liveview component
    this.onOutsideEvent = this.onOutsideEvent.bind(this)
    document.body.addEventListener('click', this.onOutsideEvent, false)
    document.body.addEventListener('focus', this.onOutsideEvent, false)
    document.body.addEventListener('blur', this.onOutsideEvent, false)

    // Use your keyboard to select a different country
    this.onKeyNavigation = this.onKeyNavigation.bind(this)
    document.body.addEventListener('keydown', this.onKeyNavigation, false)

    // When the country list overlay is open, you can type to quickly
    // jump to the country starting with your text.
    this.findPartialMatch = this.findPartialMatch.bind(this)
    document.body.addEventListener('keypress', this.findPartialMatch, false)

    // When switching from country list to input field it should close the overlay
    this.closeOverlay = this.closeOverlay.bind(this)
    this.elements.textField().addEventListener("focus", this.closeOverlay, false)
  }

  unbindEvents() {
    // Cleanup all the events we added on the body.
    document.body.removeEventListener('click', this.onOutsideEvent, false)
    document.body.removeEventListener('focus', this.onOutsideEvent, false)
    document.body.removeEventListener('blur', this.onOutsideEvent, false)
    document.body.removeEventListener('keydown', this.onKeyNavigation, false)
    document.body.removeEventListener('keypress', this.findPartialMatch, false)

    // NOTE: Not sure if we know for sure the text field still exists, so making
    // this part of the cleanup conditional.
    const textField = this.elements.textField()
    if (textField) textField.removeEventListener("focus", this.closeOverlay, false)
  }
}

// Export the LiveView Hook to manage the component lifecycle
module.exports = {
  mounted() {
    this.instance = new LivePhone(this)
    this.instance.bindEvents()
  },

  destroyed() {
    this.instance.unbindEvents()
  }
}
