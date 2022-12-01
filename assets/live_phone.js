const scrollIntoFn = 'scrollIntoView' in Element.prototype ? 'scrollIntoViewIfNeeded' : scrollIntoView


const digitsOnly = input =>
  input
  .replace(/[^0-9]/g, '') // remove all non numeric characters
  .replace(/^0*/, '') // remove leading zeros (messes it up for some countries)
  .split('') // turn into array

const maskSize = input =>
  input
  .replace(/[^X]/g, '') // remove all non masked characters
  .split('') // turn into array
  .length // return length

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
      textField: () => context.el.querySelector('input[type="tel"]'),
      hiddenField: () => context.el.querySelector('input[type="hidden"]'),
      countrySelector: () => context.el.querySelector('.live_phone-country'),
      countryList: () => context.el.querySelector('.live_phone-country-list'),
      countryListItems: () => context.el.querySelectorAll('.live_phone-country-item'),
      countryListItemNames: () => context.el.querySelectorAll('.live_phone-country-item-name'),
      selectedCountries: () => context.el.querySelectorAll('.live_phone-country-item[aria-selected="true"]'),
    }

    let masks = this.elements.textField().dataset.masks;
    if (masks) {
      this.masks = masks.split(/\s*,\s*/g)
    } else {
      this.masks = []
    }
    this.format()
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
    const changed = this.elements.hiddenField().value !== phone
    if (changed) {
      this.elements.hiddenField().value = phone
      this.elements.hiddenField().dispatchEvent(changeEvent)
    }
  }

  // This updates the mask
  setMask({masks: masks}) {
    this.masks = masks
    this.format()
  }

  // Format the visible input field using the best-match mask
  format() {
    if (!this.masks) return

    // Find all typed digits
    let digits = digitsOnly(this.elements.textField().value)
    if (!digits.length) return

    // Find the best-match mask based on digit and mask lengths
    let [currentMask] = this.masks
      .filter(mask => maskSize(mask) >= digits.length)
      .sort((a, b) => {
        let sizeA = maskSize(a)
        let sizeB = maskSize(b)
        if (sizeA < sizeB) return -1
        if (sizeA > sizeB) return 1
        return 0
      })
    if (!currentMask) return

    // Replace the mask letters with digits
    let value = currentMask.replace(/[X]/g, match => {
      let value = digits.shift()
      if (typeof value !== "string") return "X"
      return value
    })

    // Remove everything after the last typed digit
    let match = value.match(/[0-9]/g)
    if (match && match.length) {
      let lastDigitIndex = value.lastIndexOf(match[match.length - 1])
      value = value.substr(0, lastDigitIndex + 1)
    }

    this.elements.textField().value = value
  }

  // While the user typing in the input field we want to auto format it
  onInput() {
    this.format()
  }

  // When the LiveView Component gets updated it will execute this callback
  onUpdate() {
    // Update the masks (if there were previous masks set)
    let newMasks = this.elements.textField().dataset.masks
    if (this.masks && newMasks) {
      this.masks = newMasks.split(/\s*,\s*/g)
      this.format()
    }
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

    items[newSelection][scrollIntoFn]({
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
      if (!this.isOpened && this.countriesHasFocus) {
        e.preventDefault()
        document.activeElement.click()
        return
      }

      // If the country list is not open, selecting items with
      // enter should not work.
      if (!this.isOpened) {
        return
      }

      e.preventDefault()
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
    countryItemEl[scrollIntoFn]({
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

    // Get reference to textField element
    const textField = this.elements.textField()
    if (!textField) return

    // When switching from country list to input field it should close the overlay
    this.closeOverlay = this.closeOverlay.bind(this)
    textField.addEventListener("focus", this.closeOverlay, false)

    // This will help formatting input
    this.onInput = this.onInput.bind(this)
    textField.addEventListener("input", this.onInput, false)

    // Some custom code for improved autofill support, which does not always
    // trigger the correct events and cannot be observed with the MutationObserver
    const proto = Object.getPrototypeOf(textField)
    if (!proto || !proto.hasOwnProperty("value")) return
    const descriptor = Object.getOwnPropertyDescriptor(proto, "value")
    Object.defineProperty(textField, "value", {
      get() {
        return descriptor.get.apply(this, arguments)
      },

      set() {
        let previous = this.value
        descriptor.set.apply(this, arguments)
        if (this.value != previous.value) requestAnimationFrame(_ => {
          const changeEvent = new Event('keyup', {bubbles: true})
          textField.dispatchEvent(changeEvent)
        })
        return this.value
      }
    })
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
    if (textField) textField.removeEventListener("input", this.onInput, false)
  }
}

// Export the LiveView Hook to manage the component lifecycle
module.exports = {
  mounted() {
    this.instance = new LivePhone(this)
    this.instance.bindEvents()
  },

  updated() {
    this.instance.onUpdate()
  },

  destroyed() {
    this.instance.unbindEvents()
  }
}
