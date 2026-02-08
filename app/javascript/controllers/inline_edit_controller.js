import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form"]

  open() {
    this.displayTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    const input = this.formTarget.querySelector("input")
    if (input) input.focus()
  }

  close() {
    this.formTarget.classList.add("hidden")
    this.displayTarget.classList.remove("hidden")
  }
}
