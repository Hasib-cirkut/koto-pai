import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open() {
    console.log("Opening modal")
    this.dialogTarget.showModal()
    this.dialogTarget.classList.add("modal-open")
  }

  close() {
    this.dialogTarget.classList.remove("modal-open")
    this.dialogTarget.close()
  }
}
